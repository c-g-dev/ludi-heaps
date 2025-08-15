package ludi.heaps.macro;

class EnhanceObjects {

    public static function enhance() {
        no.Spoon.bend("h2d.Object", macro class {
            public var uuid: String = ludi.commons.UUID.generate();

            function onAdd() {
                DOM.notify(OnAdd(this));
                allocated = true;
                if( filter != null )
                    filter.bind(this);
                for( c in children )
                    c.onAdd();
            }

            function onRemove() {
                DOM.notify(OnRemove(this));
                allocated = false;
                if( filter != null )
                    filter.unbind(this);
                var i = children.length - 1;
                while( i >= 0 ) {
                    var c = children[i--];
                    if( c != null ) c.onRemove();
                }
            }
        });
    }
}